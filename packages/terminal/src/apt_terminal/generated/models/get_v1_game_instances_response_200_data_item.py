from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.game_instance_location_type import GameInstanceLocationType
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_instance_data_type_0 import GameInstanceDataType0


T = TypeVar("T", bound="GetV1GameInstancesResponse200DataItem")


@_attrs_define
class GetV1GameInstancesResponse200DataItem:
    """
    Attributes:
        id (str):
        definition_id (str):
        location_type (GameInstanceLocationType):
        location_id (str):
        quantity (int):
        depth (int):
        slot (None | str | Unset):
        data (GameInstanceDataType0 | None | Unset):
        object_ (Literal['game.instance'] | Unset):
    """

    id: str
    definition_id: str
    location_type: GameInstanceLocationType
    location_id: str
    quantity: int
    depth: int
    slot: None | str | Unset = UNSET
    data: GameInstanceDataType0 | None | Unset = UNSET
    object_: Literal["game.instance"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_instance_data_type_0 import GameInstanceDataType0

        id = self.id

        definition_id = self.definition_id

        location_type = self.location_type.value

        location_id = self.location_id

        quantity = self.quantity

        depth = self.depth

        slot: None | str | Unset
        if isinstance(self.slot, Unset):
            slot = UNSET
        else:
            slot = self.slot

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameInstanceDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "definition_id": definition_id,
                "location_type": location_type,
                "location_id": location_id,
                "quantity": quantity,
                "depth": depth,
            }
        )
        if slot is not UNSET:
            field_dict["slot"] = slot
        if data is not UNSET:
            field_dict["data"] = data
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_instance_data_type_0 import GameInstanceDataType0

        d = dict(src_dict)
        id = d.pop("id")

        definition_id = d.pop("definition_id")

        location_type = GameInstanceLocationType(d.pop("location_type"))

        location_id = d.pop("location_id")

        quantity = d.pop("quantity")

        depth = d.pop("depth")

        def _parse_slot(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        slot = _parse_slot(d.pop("slot", UNSET))

        def _parse_data(data: object) -> GameInstanceDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameInstanceDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameInstanceDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        object_ = cast(Literal["game.instance"] | Unset, d.pop("object", UNSET))
        if object_ != "game.instance" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'game.instance', got '{object_}'")

        get_v1_game_instances_response_200_data_item = cls(
            id=id,
            definition_id=definition_id,
            location_type=location_type,
            location_id=location_id,
            quantity=quantity,
            depth=depth,
            slot=slot,
            data=data,
            object_=object_,
        )

        get_v1_game_instances_response_200_data_item.additional_properties = d
        return get_v1_game_instances_response_200_data_item

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
