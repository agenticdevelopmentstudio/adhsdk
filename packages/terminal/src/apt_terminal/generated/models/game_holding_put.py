from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_holding_put_data import GameHoldingPutData


T = TypeVar("T", bound="GameHoldingPut")


@_attrs_define
class GameHoldingPut:
    """
    Attributes:
        artifact_id (str):
        kind (str):
        game_id (str | Unset):
        slug (str | Unset):
        quantity (int | Unset):
        data (GameHoldingPutData | Unset):
    """

    artifact_id: str
    kind: str
    game_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    quantity: int | Unset = UNSET
    data: GameHoldingPutData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        artifact_id = self.artifact_id

        kind = self.kind

        game_id = self.game_id

        slug = self.slug

        quantity = self.quantity

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "artifact_id": artifact_id,
                "kind": kind,
            }
        )
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if quantity is not UNSET:
            field_dict["quantity"] = quantity
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_holding_put_data import GameHoldingPutData

        d = dict(src_dict)
        artifact_id = d.pop("artifact_id")

        kind = d.pop("kind")

        game_id = d.pop("game_id", UNSET)

        slug = d.pop("slug", UNSET)

        quantity = d.pop("quantity", UNSET)

        _data = d.pop("data", UNSET)
        data: GameHoldingPutData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = GameHoldingPutData.from_dict(_data)

        game_holding_put = cls(
            artifact_id=artifact_id,
            kind=kind,
            game_id=game_id,
            slug=slug,
            quantity=quantity,
            data=data,
        )

        game_holding_put.additional_properties = d
        return game_holding_put

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
