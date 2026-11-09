from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_holding_data_type_0 import GameHoldingDataType0


T = TypeVar("T", bound="GameHolding")


@_attrs_define
class GameHolding:
    """
    Attributes:
        id (str):
        game_id (str):
        artifact_id (str):
        kind (str):
        quantity (int):
        acquired_at (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        data (GameHoldingDataType0 | None | Unset):
    """

    id: str
    game_id: str
    artifact_id: str
    kind: str
    quantity: int
    acquired_at: str
    created: int
    updated: int
    data: GameHoldingDataType0 | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.game_holding_data_type_0 import GameHoldingDataType0

        id = self.id

        game_id = self.game_id

        artifact_id = self.artifact_id

        kind = self.kind

        quantity = self.quantity

        acquired_at = self.acquired_at

        created = self.created

        updated = self.updated

        data: dict[str, Any] | None | Unset
        if isinstance(self.data, Unset):
            data = UNSET
        elif isinstance(self.data, GameHoldingDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "game_id": game_id,
                "artifact_id": artifact_id,
                "kind": kind,
                "quantity": quantity,
                "acquired_at": acquired_at,
                "created": created,
                "updated": updated,
            }
        )
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_holding_data_type_0 import GameHoldingDataType0

        d = dict(src_dict)
        id = d.pop("id")

        game_id = d.pop("game_id")

        artifact_id = d.pop("artifact_id")

        kind = d.pop("kind")

        quantity = d.pop("quantity")

        acquired_at = d.pop("acquired_at")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_data(data: object) -> GameHoldingDataType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = GameHoldingDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GameHoldingDataType0 | None | Unset, data)

        data = _parse_data(d.pop("data", UNSET))

        game_holding = cls(
            id=id,
            game_id=game_id,
            artifact_id=artifact_id,
            kind=kind,
            quantity=quantity,
            acquired_at=acquired_at,
            created=created,
            updated=updated,
            data=data,
        )

        game_holding.additional_properties = d
        return game_holding

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
