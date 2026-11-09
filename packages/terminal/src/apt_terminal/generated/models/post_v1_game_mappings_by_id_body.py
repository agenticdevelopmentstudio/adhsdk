from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GameMappingsByIdBody")


@_attrs_define
class PostV1GameMappingsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        game_id (str | Unset):
        from_id (str | Unset):
        kind (str | Unset):
        to_id (str | Unset):
        amount (int | Unset):
        sort_order (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    game_id: str | Unset = UNSET
    from_id: str | Unset = UNSET
    kind: str | Unset = UNSET
    to_id: str | Unset = UNSET
    amount: int | Unset = UNSET
    sort_order: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        game_id = self.game_id

        from_id = self.from_id

        kind = self.kind

        to_id = self.to_id

        amount = self.amount

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if from_id is not UNSET:
            field_dict["from_id"] = from_id
        if kind is not UNSET:
            field_dict["kind"] = kind
        if to_id is not UNSET:
            field_dict["to_id"] = to_id
        if amount is not UNSET:
            field_dict["amount"] = amount
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        game_id = d.pop("game_id", UNSET)

        from_id = d.pop("from_id", UNSET)

        kind = d.pop("kind", UNSET)

        to_id = d.pop("to_id", UNSET)

        amount = d.pop("amount", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        post_v1_game_mappings_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            game_id=game_id,
            from_id=from_id,
            kind=kind,
            to_id=to_id,
            amount=amount,
            sort_order=sort_order,
        )

        return post_v1_game_mappings_by_id_body
